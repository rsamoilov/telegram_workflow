require "telegram_workflow/rspec"

module RSpecSpec
  class Appointment
    def self.create!(params)
    end
  end

  class CreateAppointment < TelegramWorkflow::Action
    def initial
      on_redirect do
        client.send_message text: "Enter patient's name:"
      end

      on_message do
        flash[:name] = params.message_text
        redirect_to :date
      end
    end

    def date
      on_redirect do
        client.send_message text: "What date works best for you?"
      end

      on_message do
        is_date_valid = Date.parse(params.message_text) rescue false

        if is_date_valid
          flash[:date] = params.message_text
          redirect_to :done
        else
          client.send_message text: "Invalid date format. Please try again."
        end
      end
    end

    def done
      on_redirect do
        Appointment.create!(flash.slice(:name, :date))
        client.send_message text: "Your appointment has been created!"
        redirect_to ListAppointments
      end
    end
  end

  class ListAppointments < TelegramWorkflow::Action
    def initial
    end
  end
end

RSpec.describe RSpecSpec::CreateAppointment, type: :telegram_action do
  let!(:params) { { name: "Test User Name", date: "10/10/2000" } }

  it "creates an appointment" do
    expect(subject.client).to have_received(:send_message).with(text: "Enter patient's name:")

    send_message message_text: params[:name]
    expect(subject.client).to have_received(:send_message).with(text: "What date works best for you?")

    expect(RSpecSpec::Appointment).to receive(:create!).with(params).once

    send_message message_text: params[:date]
    expect(subject.client).to have_received(:send_message).with(text: "Your appointment has been created!")
    expect(subject.flow).to have_received(:redirect_to).with(RSpecSpec::ListAppointments)
  end

  it "validates the date" do
    send_message message_text: params[:name]

    send_message message_text: "invalid_date"
    expect(subject.client).to have_received(:send_message).with(text: "Invalid date format. Please try again.")
    expect(subject.flow).not_to have_received(:redirect_to).with(:done)

    send_message message_text: params[:date]
    expect(subject.flow).to have_received(:redirect_to).with(:done)
  end
end
