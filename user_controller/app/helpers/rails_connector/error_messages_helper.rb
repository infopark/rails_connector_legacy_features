module RailsConnector
  module ErrorMessagesHelper
    # Shortened error_messages_for from git://github.com/rails/dynamic_form.git
    def error_messages(*objects)
      objects.compact!
      count = objects.inject(0) {|sum, object| sum + object.errors.count }
      return '' if count.zero?

      content_tag(:div, :class => 'errorExplanation') do
        c = ''.html_safe
        c << content_tag(:ul) do
          li = ''.html_safe
          objects.each do |object|
            object.errors.full_messages.each do |msg|
              li << content_tag(:li, msg)
            end
          end
          li
        end
      end
    end
  end
end
