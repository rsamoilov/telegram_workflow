RSpec.describe TelegramWorkflow::Session do
  let!(:user_id) { 12333444 }
  let!(:params) { TelegramWorkflow::Params.new("message" => { "from" => { "id" => user_id } }) }

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

  context "user session" do
    it "initializes a user session" do
      expect(subject.user_session).to be_empty
      expect(subject.user_session).to be_a(Hash)
    end

    it "can be persisted" do
      value = 1112

      subject.user_session.merge!(user_id: value)
      expect(subject.user_session[:user_id]).to eq(value)
      expect(subject.reload.user_session[:user_id]).to eq(value)
    end

    it "doesn't affect the main session" do
      subject.write(:chat_id, 12345)
      subject.user_session.merge!(user_id: 334)
      subject.reload

      expect(subject.user_session.keys).to eq(%i(user_id))
      expect(subject.read(:chat_id)).to be_present
      expect(subject.read(:user_id)).to be_nil
    end
  end

  context "flash session" do
    it "initializes a flash session" do
      expect(subject.flash).to be_empty
      expect(subject.flash).to be_a(Hash)
    end

    it "can be persisted" do
      value = "test value"

      subject.flash.merge!(temp_key: value)
      expect(subject.flash[:temp_key]).to eq(value)
      expect(subject.reload.flash[:temp_key]).to eq(value)
    end

    it "can store objects" do
      first_name, last_name, dob = "Test", "User", Date.today
      subject.flash.merge!(test_key: { first_name: first_name, last_name: last_name, dob: dob })

      [subject.flash[:test_key], subject.reload.flash[:test_key]].each do |f|
        expect(f[:first_name]).to eq(first_name)
        expect(f[:last_name]).to eq(last_name)
        expect(f[:dob]).to eq(dob)
      end
    end

    it "can be cleared" do
      value = "test value"

      subject.flash.merge!(test_key: value)
      expect(subject.reload.flash[:test_key]).to eq(value)

      subject.reset_flash
      expect(subject.flash).to be_empty
      expect(subject.reload.flash).to be_empty
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
