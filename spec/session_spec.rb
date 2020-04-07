RSpec.describe TelegramWorkflow::Session do
  let!(:user_id) { 12333444 }
  let!(:params) { TelegramWorkflow::Params.new(message: { from: { id: user_id } }) }

  subject { TestSession.new(params) }

  context "when there is no session" do
    it "correctly sets a string key" do
      key, value = "test_key", "test value"
      expect { subject.write(key, value) }.to change { subject.read(key) }.from(nil).to(value)
      expect(subject.reload.read(key)).to eq(value)
    end

    it "correctly sets a symbol key" do
      key, value = :test_key, "test value"
      expect { subject.write(key, value) }.to change { subject.read(key) }.from(nil).to(value)
      expect(subject.reload.read(key)).to eq(value)
    end

    it "allows to delete a non-existent key" do
      expect { subject.delete(:non_existent_key) }.not_to raise_error
    end

    it "allows to clear an empty session" do
      expect { subject.clear }.not_to raise_error
    end
  end

  context "when the session exists" do
    let!(:chat_id) { 12345 }
    let!(:user) { { id: 2234, name: "Test User" } }
    let!(:friend_ids) { [1, 2, 4, 6] }

    before do
      TelegramWorkflow.config.session_store.write(user_id, Marshal.dump({
        chat_id: chat_id,
        user: user,
        friend_ids: friend_ids
      }))
    end

    it "correctly reads the session" do
      expect(subject.read(:chat_id)).to eq(chat_id)
      expect(subject.read(:user)).to eq(user)
      expect(subject.read(:friend_ids)).to eq(friend_ids)
    end

    it "deletes a key" do
      expect { subject.delete(:user) }.to change { subject.read(:user) }.to(nil)
      expect(subject.reload.read(:user)).to be_nil
    end

    it "clears the session" do
      keys = %i(chat_id user friend_ids)

      subject.clear
      keys.each { |key| expect(subject.read(key)).to be_nil }

      reloaded_session = subject.reload
      keys.each { |key| expect(reloaded_session.read(key)).to be_nil }
    end
  end

  context "action session" do
    it "initializes an action session" do
      expect(subject.action_session).to be_empty
      expect(subject.action_session).to be_a(Hash)
    end

    it "can be persisted" do
      value = "test value"

      subject.action_session.merge!(test_key: value)
      expect(subject.action_session[:test_key]).to eq(value)
      expect(subject.reload.action_session[:test_key]).to eq(value)
    end

    it "can store objects" do
      value = { first_name: "Test", last_name: "User", dob: "01/02/1900" }

      subject.action_session.merge!(test_key: value)
      expect(subject.action_session[:test_key]).to eq(value)
      expect(subject.reload.action_session[:test_key]).to eq(value)
    end

    it "can be cleared" do
      value = "test value"

      subject.action_session.merge!(test_key: value)
      expect(subject.reload.action_session[:test_key]).to eq(value)

      subject.reset_action_session
      expect(subject.action_session).to be_empty
      expect(subject.reload.action_session).to be_empty
    end

    it "doesn't affect the main session" do
      subject.write(:chat_id, 12345)
      subject.action_session.merge!(temp_key: "temp value")
      subject.reload && subject.reset_action_session

      expect(subject.action_session).to be_empty
      expect(subject.read(:chat_id)).to be_present
    end
  end
end

# a wrapper around a Session object that adds a `reload` method
class TestSession
  def initialize(params)
    @params = params
    @session = TelegramWorkflow::Session.new(@params)
  end

  def method_missing(method_name, *args)
    @session.public_send(method_name, *args)
  end

  def reload
    @session.dump
    TelegramWorkflow::Session.new(@params)
  end
end
