class OneoffUnoapiCampaignJob < ApplicationJob
  queue_as :high

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    Whatsapp::OneoffUnoapiCampaignService.new(campaign: campaign).perform
  end
end