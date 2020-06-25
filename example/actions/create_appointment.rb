#
# this is an action to create an appointment;
# each method represents one of the steps for appointment creation;
# for the sake of simplicity, all created appointments are stored in the session
#
class Actions::CreateAppointment < TelegramWorkflow::Action
  def initial
    on_redirect do
      client.send_message text: "Enter patient's name:"
    end

    on_message do
      flash[:name] = params.message_text
      redirect_to :reason
    end
  end

  def reason
    on_redirect do
      client.send_message text: "What is the reason for visit?"
    end

    on_message do
      flash[:reason] = params.message_text
      redirect_to :date
    end
  end

  def date
    on_redirect do
      client.send_message text: "What date works best for you?"
    end

    on_message do
      date = Date.parse(params.message_text) rescue nil

      # there's no redirect in case the date is invalid;
      # this means that next time a user sends a message, the current action will be executed again
      if date
        flash[:date] = date
        redirect_to :done
      else
        client.send_message text: "Invalid date format. Please try again."
      end
    end
  end

  # `specialty` parameter is added to flash in previous `Actions::SelectDoctor` action
  def done
    on_redirect do
      (session[:appointments] ||= []) << flash.slice(:name, :reason, :date, :specialty)
      client.send_message text: "Your appointment has been created!"
      redirect_to Actions::ListActions
    end
  end
end
