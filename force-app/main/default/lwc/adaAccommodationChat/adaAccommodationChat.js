import { LightningElement, track } from 'lwc';
import chat from '@salesforce/apex/AdaAgentService.chat';

const WELCOME_MESSAGE = {
    id: 'welcome',
    text: `Hi, I'm Ada — your workplace accommodation advocate. This is a safe, confidential space and I'm here to help you at your own pace, with no judgment.\n\nI can help you explore accommodation options, draft a professional letter, submit a request, or check on a request you've already submitted.\n\nWhat's been making work difficult for you lately?`,
    isAda: true,
    timestamp: new Date()
};

const MIN_FONT = 14;
const MAX_FONT = 22;
const FONT_STEP = 2;

export default class AdaAccommodationChat extends LightningElement {
    @track messages = [];
    @track inputText = '';
    @track isTyping = false;
    @track isSending = false;
    @track isHighContrast = false;
    @track statusMessage = '';
    @track statusType = '';
    @track liveRegionText = '';

    fontSize = 16;

    connectedCallback() {
        this.messages = [this._buildMessage(WELCOME_MESSAGE.text, true)];
        this._announceToScreenReader('Ada, accommodation advocate, is ready. ' + WELCOME_MESSAGE.text);
        this._applyFontSize();
    }

    // --- Accessibility controls ---

    toggleHighContrast() {
        this.isHighContrast = !this.isHighContrast;
        const wrapper = this.template.querySelector('.ada-wrapper');
        if (wrapper) {
            wrapper.classList.toggle('ada-wrapper--high-contrast', this.isHighContrast);
        }
        this._announceToScreenReader(
            this.isHighContrast ? 'High contrast mode enabled.' : 'High contrast mode disabled.'
        );
    }

    increaseFontSize() {
        if (this.fontSize < MAX_FONT) {
            this.fontSize += FONT_STEP;
            this._applyFontSize();
            this._announceToScreenReader('Text size increased to ' + this.fontSize + ' pixels.');
        }
    }

    decreaseFontSize() {
        if (this.fontSize > MIN_FONT) {
            this.fontSize -= FONT_STEP;
            this._applyFontSize();
            this._announceToScreenReader('Text size decreased to ' + this.fontSize + ' pixels.');
        }
    }

    _applyFontSize() {
        const wrapper = this.template.querySelector('.ada-wrapper');
        if (wrapper) {
            wrapper.style.setProperty('--ada-font-size', this.fontSize + 'px');
        }
    }

    handleSkipLink(evt) {
        evt.preventDefault();
        const main = this.template.querySelector('#ada-chat-main');
        if (main) {
            main.setAttribute('tabindex', '-1');
            main.focus();
        }
    }

    // --- Input handling ---

    handleFormSubmit(evt) {
        evt.preventDefault();
    }

    handleInput(evt) {
        this.inputText = evt.target.value;
    }

    handleKeyDown(evt) {
        if (evt.key === 'Enter' && !evt.shiftKey) {
            evt.preventDefault();
            this.sendMessage();
        }
    }

    // --- Message sending ---

    async sendMessage() {
        const text = this.inputText.trim();
        if (!text || this.isSending) return;

        this.inputText = '';
        const form = this.template.querySelector('form.ada-input-form');
        if (form) form.reset();
        this.isSending = true;
        this.statusMessage = '';

        this.messages = [...this.messages, this._buildMessage(text, false)];
        this._scrollToBottom();

        this.isTyping = true;
        this._announceToScreenReader('Message sent. Ada is responding.');

        try {
            const response = await this._callAgent(text);
            this.isTyping = false;
            const adaMessage = this._buildMessage(response, true);
            this.messages = [...this.messages, adaMessage];
            this._announceToScreenReader('Ada replied: ' + response);
            this._scrollToBottom();
        } catch (err) {
            this.isTyping = false;
            this._showStatus('error', 'Something went wrong. Please try again or contact HR directly.');
            this._announceToScreenReader('Error sending message. Please try again.');
        } finally {
            this.isSending = false;
            this._focusInput();
        }
    }

    // --- GenAI Prompt Template via Apex ----------------------------------------

    async _callAgent(userMessage) {
        const history = this.messages
            .filter(m => m.id !== 'welcome')
            .map(m => (m.isAda ? 'Ada: ' : 'Employee: ') + m.text)
            .join('\n');

        return chat({ userMessage, conversationHistory: history });
    }

    // --- Helpers ---

    _buildMessage(text, isAda) {
        const now = new Date();
        const id = (isAda ? 'ada-' : 'user-') + now.getTime();
        return {
            id,
            text,
            isAda,
            timestamp: now,
            isoTime: now.toISOString(),
            displayTime: now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            timeLabel: 'Sent at ' + now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            cssClass: 'ada-message' + (isAda ? ' ada-message--ada' : ' ada-message--user'),
            ariaLabel: (isAda ? 'Ada: ' : 'You: ') + text
        };
    }

    _announceToScreenReader(text) {
        this.liveRegionText = '';
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.liveRegionText = text; }, 50);
    }

    _scrollToBottom() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const log = this.template.querySelector('.ada-messages');
            if (log) log.scrollTop = log.scrollHeight;
        }, 50);
    }

    _focusInput() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const input = this.template.querySelector('#ada-input');
            if (input) {
                input.value = '';
                input.focus();
            }
        }, 50);
    }

    _showStatus(type, message) {
        this.statusType = type;
        this.statusMessage = message;
    }

    // --- Computed properties ---

    get isSendDisabled() {
        return !this.inputText.trim() || this.isSending;
    }

    get highContrastButtonClass() {
        return 'ada-control-btn' + (this.isHighContrast ? ' ada-control-btn--active' : '');
    }

    get statusCssClass() {
        return 'ada-status ada-status--' + this.statusType;
    }

    get statusIcon() {
        return this.statusType === 'error' ? '⚠' : '✓';
    }
}
