<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ResolveAction from '../../buttons/ResolveAction.vue';
import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

export default {
  components: {
    EmailTranscriptModal,
    ResolveAction,
  },
  data() {
    return {
      showEmailActionsModal: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      callInfo: 'webphone/getCallInfo',
    }),
    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.currentChat.meta.sender.id
      );
    },
  },
  mounted() {
    this.$emitter.on(CMD_MUTE_CONVERSATION, this.mute);
    this.$emitter.on(CMD_UNMUTE_CONVERSATION, this.unmute);
    this.$emitter.on(CMD_SEND_TRANSCRIPT, this.toggleEmailActionsModal);
  },
  destroyed() {
    this.$emitter.off(CMD_MUTE_CONVERSATION, this.mute);
    this.$emitter.off(CMD_UNMUTE_CONVERSATION, this.unmute);
    this.$emitter.off(CMD_SEND_TRANSCRIPT, this.toggleEmailActionsModal);
  },
  methods: {
    mute() {
      this.$store.dispatch('muteConversation', this.currentChat.id);
      useAlert(this.$t('CONTACT_PANEL.MUTED_SUCCESS'));
    },
    unmute() {
      this.$store.dispatch('unmuteConversation', this.currentChat.id);
      useAlert(this.$t('CONTACT_PANEL.UNMUTED_SUCCESS'));
    },
    toggleEmailActionsModal() {
      this.showEmailActionsModal = !this.showEmailActionsModal;
    },
    async startCall() {
      try {
        await this.$store.dispatch('webphone/outcomingCall', {
          contact_name: this.currentContact.name,
          profile_picture: this.currentContact.thumbnail,
          phone: this.currentContact.phone_number,
          chat_id: this.currentChat.id,
        });
      } catch (error) {
        if (error.message === 'Numero não existe') {
          useAlert(this.$t('WEBPHONE.CONTACT_INVALID'));
        } else if (
          error.message === 'Linha ocupada, tente mais tarde ou faça um upgrade'
        ) {
          useAlert(this.$t('WEBPHONE.ALL_INSTANCE_BUSY'));
        } else if (error.message === 'Limite de ligações atingido') {
          useAlert(this.$t('WEBPHONE.CALL_LIMIT'));
        } else {
          useAlert(
            `${this.$t('WEBPHONE.ERROR_TO_MADE_CALL')}: ${error.message}`
          );
        }
      }
    },
  },
};
</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <woot-button
      v-tooltip="$t('WEBPHONE.CALL')"
      variant="clear"
      color-scheme="secondary"
      icon="call"
      :disabled="callInfo.id"
      @click="startCall"
    />
    <woot-button
      v-if="!currentChat.muted"
      v-tooltip="$t('CONTACT_PANEL.MUTE_CONTACT')"
      variant="clear"
      color-scheme="secondary"
      icon="speaker-mute"
      @click="mute"
    />
    <woot-button
      v-else
      v-tooltip.left="$t('CONTACT_PANEL.UNMUTE_CONTACT')"
      variant="clear"
      color-scheme="secondary"
      icon="speaker-1"
      @click="unmute"
    />
    <woot-button
      v-tooltip="$t('CONTACT_PANEL.SEND_TRANSCRIPT')"
      variant="clear"
      color-scheme="secondary"
      icon="share"
      @click="toggleEmailActionsModal"
    />
    <ResolveAction
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailActionsModal"
    />
  </div>
</template>

<style scoped lang="scss">
.more--button {
  @apply items-center flex ml-2 rtl:ml-0 rtl:mr-2;
}

.dropdown-pane {
  @apply -right-2 top-12;
}

.icon {
  @apply mr-1 rtl:mr-0 rtl:ml-1 min-w-[1rem];
}
</style>
