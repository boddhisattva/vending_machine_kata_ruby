# frozen_string_literal: true

class ApplicationRunner
  def initialize(display, input_handler, menu_router)
    @display = display
    @input_handler = input_handler
    @menu_router = menu_router
  end

  def run
    @display.show_welcome_message

    loop do
      @display.show_menu_options
      choice = @input_handler.get_menu_choice

      @menu_router.route(choice)
      break if @menu_router.quit_command?(choice)

      puts "\n"
    end
  end
end
