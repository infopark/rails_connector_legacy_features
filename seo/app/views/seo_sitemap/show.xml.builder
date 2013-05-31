base_url = request.protocol + request.host_with_port
xml.instruct!
xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9') {
  for obj in @objects do
    prio = obj.root? ? 1.0 : (1.0 - (obj.path.split('/').length - 1) * 0.1)
    prio *= (obj.file_extension == 'pdf' ? 1.2 : 0.5) if obj.binary?
    if (prio >= 0.1)
      prio = 1.0 if prio > 1.0
      xml.url {
        xml.loc base_url, cms_path(obj)
        xml.lastmod(obj.last_changed.blank? ? nil : obj.last_changed.strftime('%Y-%m-%d'))
        xml.priority((prio * 100).round / 100.0).to_s
      }
    end
  end
}
