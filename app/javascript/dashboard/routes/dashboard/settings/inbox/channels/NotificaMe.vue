<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import notificaMeChannel from '../../../../../api/channel/notificaMeChannel';

export default {
  components: {
    PageHeader,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      notificaMeId: '',
      notificaMeToken: '',
      notificaMeType: '',
      channels: [],
      channelsLabels: {
        telegram: 'Telegram',
        facebook: 'Facebook',
        whatsapp_business_account: 'Whatsapp API Oficial',
        sms: 'SMS',
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },

  watch: {
    notificaMeToken() {
      this.fetchChannels(this.notificaMeToken);
    },
  },
  validations: {
    channelName: { required },
    notificaMeToken: { required },
    notificaMeId: { required },
  },
  methods: {
    async fetchChannels(token) {
      if (!token) {
        this.v$.notificaMeToken.$touch();
        return;
      }
      try {
        this.channels = [];
        const resp = await notificaMeChannel.get(token);
        this.channels = resp.data.data.channels.map(c => {
          c.type = c.channel;
          return c;
        });
      } catch (error) {
        // resp.data.errors
        this.channels = [];
      }
    },

    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.notificaMeType = this.channels.find(
        c => c.id === this.notificaMeId
      )?.type;
      try {
        const channel = await this.$store.dispatch(
          'inboxes/createNotificaMeChannel',
          {
            notifica_me_channel: {
              name: this.channelName,
              notifica_me_token: this.notificaMeToken,
              notifica_me_id: this.notificaMeId,
              notifica_me_type: this.notificaMeType,
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: channel.id,
          },
        });
      } catch (error) {
        useAlert(
          this.$t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.DESC')"
    />
    <form class="mx-0 flex flex-wrap" @submit.prevent="createChannel()">
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.notificaMeToken.$error }">
          {{ $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL_TOKEN.LABEL') }}
          <input
            v-model.trim="notificaMeToken"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL_TOKEN.PLACEHOLDER')
            "
            @blur="v$.notificaMeToken.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL_TOKEN.SUBTITLE') }}
        </p>
      </div>

      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: v$.notificaMeId.$error }">
          {{ $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL.LABEL') }}
          <select v-model.trim="notificaMeId" @blur="v$.notificaMeId.$touch">
            <option value="">
              {{ $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL.PLACEHOLDER') }}
            </option>

            <option
              v-for="channel in channels"
              :key="channel.id"
              :value="channel.id"
            >
              {{ channelsLabels[channel.type] || channel.type }}:
              {{ channel.name }}
            </option>
          </select>
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.CHANNEL.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.NOTIFICA_ME_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
