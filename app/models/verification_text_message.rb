# == Schema Information
#
# Table name: text_message_login_requests
#
#  id                           :bigint           not null, primary key
#  twilio_sid                   :string
#  text_message_access_token_id :bigint           not null
#  visitor_id                   :string           not null
#
# Indexes
#
#  index_text_message_login_requests_on_twilio_sid  (twilio_sid)
#  index_text_message_login_requests_on_visitor_id  (visitor_id)
#  text_message_login_request_access_token_id       (text_message_access_token_id)
#
class VerificationTextMessage < ApplicationRecord
  self.ignored_columns = [:twilio_status]
  self.table_name = "text_message_login_requests"
  belongs_to :text_message_access_token
  validates_presence_of :visitor_id
end
