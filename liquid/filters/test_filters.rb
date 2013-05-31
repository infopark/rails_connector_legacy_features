# Dieser Filter dient als "Fixture" für die Specs des LiquidTemplateHandlers
module TestFilters

  def spamify(source)
    "spam and #{source}"
  end

  def headline(source, level)
    tag = "h#{level}"
    "<#{tag}>#{source}</#{tag}>"
  end

  def replace(source, str, replacement)
    source.gsub(str, replacement)
  end

end
