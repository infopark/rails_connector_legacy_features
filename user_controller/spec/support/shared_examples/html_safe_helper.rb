shared_examples_for "an html safe helper" do
  it "returns html safe output" do
    html_safe_output.should be_html_safe
  end
end
