require 'nokogiri'

module RSpec::Matchers
  class HaveTag
    ALLOWED_OPTIONS = [:count, :minimum, :maximum, :strip, :inner_text]

    def initialize(selector, inner_text_or_options, options, &block)
      @selector = selector
      if Hash === inner_text_or_options
        @inner_text = nil
        @options = inner_text_or_options
      else
        @inner_text = inner_text_or_options
        @options = options
      end
      illegal_options = (@options.keys - ALLOWED_OPTIONS)
      unless illegal_options.empty?
        raise "Illegal have_tag options: #{illegal_options.join(", ")}"
      end
    end

    def matches?(actual, &block)
      @actual = actual
      @hdoc = hdoc_for(@actual)

      matched_elements = @hdoc.search(@selector)
      if matched_elements.empty?
        return @options[:count] == 0
      end

      if @inner_text
        matched_elements = filter_on_inner_text(matched_elements)
      end

      if block
        matched_elements = filter_on_nested_expectations(matched_elements, block)
      end

      @actual_count = matched_elements.length
      return false if not acceptable_count?(@actual_count)

      !matched_elements.empty?
    end

    def failure_message
      explanation = @actual_count ? "but found #{@actual_count}" : "but did not"
      message = "expected\n#{@hdoc}\nto have #{failure_count_phrase} #{failure_selector_phrase}, #{explanation}"
      unless nested_exceptions.blank?
        nested_exceptions.each do |e|
          message << "\nroot cause: #{e.message.gsub(/expected.*to have an element/m, "expected matched #{failure_selector_phrase} to have an element")}"
        end
      end
      message
    end

    def negative_failure_message
      explanation = @actual_count ? "but found #{@actual_count}" : "but did"
      "expected\n#{@hdoc}\nnot to have #{failure_count_phrase} #{failure_selector_phrase}, #{explanation}"
    end

    protected

    def nested_exceptions
      @nested_exceptions ||= []
    end

    private

      def hdoc_for(input)
        if Nokogiri::XML::Document === input
          input
        elsif input.respond_to?(:body)
          Nokogiri::HTML(input.body)
        else
          Nokogiri::HTML(input.to_s)
        end
      end

      def filter_on_inner_text(elements)
        elements.select do |el|
          next(el.inner_text =~ @inner_text) if @inner_text.is_a?(Regexp)
          #
          # Use #inner_html instead of #inner_text for #inner_text unescapes the HTML entities, e.g.
          # Nokogiri::HTML("<foo>&lt;bar/&gt;</foo>").inner_text #=> "<foo><bar/></foo>"
          # Nokogiri::HTML("<foo>&lt;bar/&gt;</foo>").inner_html #=> "<foo>&lt;bar/&gt;</foo>"
          #
          # In order to check text of a text node use a string:
          #   tag.should have_tag("ul li a span", "click me")
          #
          # In order to check text _somewhere_ inside a node structure use a regexp:
          #   tag.should have_tag("ul", /click me/)
          #
          # ENHANCED (kaiuwe: no entities and stripped)
          text = @options[:inner_text] ? el.inner_text : el.inner_html
          text = text.strip if @options[:strip]
          # /ENHANCED
          text == @inner_text
        end
      end

      def filter_on_nested_expectations(elements, block)
        elements.select do |el|
          begin
            block.call(el)
          rescue RSpec::Expectations::ExpectationNotMetError => e
            nested_exceptions << e
            false
          else
            true
          end
        end
      end

      def acceptable_count?(actual_count)
        if @options[:count]
          return false unless @options[:count] === actual_count
        end
        if @options[:minimum]
          return false unless actual_count >= @options[:minimum]
        end
        if @options[:maximum]
          return false unless actual_count <= @options[:maximum]
        end
        true
      end

      def failure_count_phrase
        if @options[:count]
          "#{@options[:count]} elements matching"
        elsif @options[:minimum] || @options[:maximum]
          count_explanations = []
          count_explanations << "at least #{@options[:minimum]}" if @options[:minimum]
          count_explanations << "at most #{@options[:maximum]}"  if @options[:maximum]
          "#{count_explanations.join(' and ')} elements matching"
        else
          "an element matching"
        end
      end

      def failure_selector_phrase
        phrase = @selector.inspect
        phrase << (@inner_text ? " with inner text #{@inner_text.inspect}" : "")
      end
  end

  def have_tag(selector, inner_text_or_options = nil, options = {}, &block)
    HaveTag.new(selector, inner_text_or_options, options, &block)
  end

  def have_stripped_text(selector, inner_text, options = {}, &block)
    HaveTag.new(selector, inner_text, options.merge(:strip => true, :inner_text => true), &block)
  end
end
