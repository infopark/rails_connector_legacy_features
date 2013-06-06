module RailsConnector

  # A helper to access the preview time machine.
  # @api public
  module TimeMachineHelper

    # Renders a link to open the time machine.
    # @api public
    def time_machine_link(content)
      if Configuration.enabled?(:time_machine) && Configuration.editor_interface_enabled?
        (<<-EOF).html_safe
          #{link_to_function content, "window.open('#{time_machine_url :action => 'index'}', 'time_machine', 'height=350,location=no,menubar=no,status=no,toolbar=no,width=500')"}
          <script type="text/javascript">
          // <!--
            function sendRequest(url)
            {
              jQuery.getScript(url);
            }
          // -->
          </script>
        EOF
      end
    end
  end

end