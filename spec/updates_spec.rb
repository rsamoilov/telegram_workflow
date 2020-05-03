RSpec.describe TelegramWorkflow::Updates do
  let!(:params) { {} }
  let!(:client) { double }

  subject { TelegramWorkflow::Updates.new(params) }

  before do
    allow(TelegramWorkflow::Client).to receive(:new).and_return(client)
  end

  it "returns a enumerator" do
    expect(subject.enum).to be_a(Enumerator)
  end

  it "doesn't query the API on initialization" do
    expect(client).not_to receive(:get_updates)
    subject.enum
  end

  it "returns the updates" do
    update1 = { "body" => "test body 1", "update_id" => 935660653 }
    update2 = { "body" => "test body 2", "update_id" => 935660654 }
    updates = { "result" => [update1, update2] }

    expect(client).to receive(:get_updates).
      with({}).
      once.
      and_return(updates)

    enum = subject.enum
    expect(enum.next).to eq(update1)
    expect(enum.next).to eq(update2)

    expect(client).to receive(:get_updates).
      once.
      with({ offset: update2["update_id"] + 1 }).
      and_return(updates)
    enum.next
  end
end
