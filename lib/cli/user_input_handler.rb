class UserInputHandler
  def get_menu_choice
    input = safe_gets
    return 'q' if input.nil?

    input.chomp.downcase
  end

  def get_item_number
    print 'Enter item number to purchase: '
    input = safe_gets
    return nil if input.nil?

    input.to_i
  end

  def get_payment_input
    print "Enter payment hash (or 'cancel' to cancel): "
    safe_gets
  end

  def request_any_key
    print 'Press Enter to continue...'
    safe_gets
  end

  def safe_gets
    input = $stdin.gets
    return nil if input.nil?

    input.chomp
  end
end
