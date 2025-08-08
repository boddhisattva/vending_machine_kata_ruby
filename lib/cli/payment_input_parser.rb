class PaymentInputParser
  def parse(input)
    return nil unless input_looks_like_hash?(input)

    content = extract_hash_content(input)
    return {} if content_is_empty?(content)

    build_payment_from_content(content)
  rescue StandardError => e
    show_parsing_error(e)
    nil
  end

  private

  def input_looks_like_hash?(input)
    clean_input = input.strip

    unless clean_input.match?(/\A\s*\{.*\}\s*\z/)
      puts 'Invalid format. Input must be in hash format like {100 => 2, 50 => 1}'
      return false
    end

    true
  end

  def extract_hash_content(input)
    input.strip[/{(.*)}/m, 1]
  end

  def content_is_empty?(content)
    content.nil? || content.strip.empty?
  end

  def build_payment_from_content(content)
    payment = {}
    coin_entries = split_into_coin_entries(content)

    coin_entries.each do |entry|
      denomination, count = parse_single_coin_entry(entry)
      return nil unless denomination && count

      return nil unless count_is_valid?(count)

      payment[denomination] = count
    end

    payment
  end

  def split_into_coin_entries(content)
    content.split(',').map(&:strip)
  end

  def parse_single_coin_entry(entry)
    match = entry.match(/\A\s*(\d+)\s*=>\s*(\d+)\s*\z/)

    unless match
      puts "Invalid pair format: '#{entry}'. Expected format: 'denomination => count'"
      return [nil, nil]
    end

    [match[1].to_i, match[2].to_i]
  end

  def count_is_valid?(count)
    if count <= 0
      puts "Invalid count: #{count}. Count must be positive."
      return false
    end

    true
  end

  def show_parsing_error(error)
    puts "Error parsing payment hash: #{error.message}"
    puts 'Please use the format: {100 => 2, 25 => 1}'
  end
end
