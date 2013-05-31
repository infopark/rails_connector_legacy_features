xml.instruct! :xml, :version => '1.0'

xml.rss :version => '2.0' do
  xml.channel do
    xml.title display_value(@obj.title)
    xml.link cms_url(@obj)
    xml.description strip_tags(display_value(@obj.rss_description))

    xml << (render(:partial => "item", :collection => table_of_contents(@obj))).to_s
  end
end
