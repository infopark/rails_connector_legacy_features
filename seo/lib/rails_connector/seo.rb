module RailsConnector
  # Search Engine Optimization methods
  module SEO

    # The methods contained herein are attached to the Obj model class.
    module ClassMethods
      # Finds all objects that shall be included in the SEO <tt>sitemap.xml</tt>.
      # On each exportable none-image object, {InstanceMethods#included_in_seo_sitemap?} is called.
      # Overwrite <tt>included_in_seo_sitemap?</tt> in your {Obj} to adjust the criteria.
      def find_all_for_sitemap
        start = Obj.homepage
        children = start.toclist
        grandchildren = children.map(&:toclist).flatten

        ([start] + children + grandchildren).select(&:included_in_seo_sitemap?)
      end
    end

    # The methods contained herein are included in the Obj model.
    module InstanceMethods

      # Returns +true+ by default. Overwrite in your {Obj} as you like.
      def readable_for_googlebots?
        true
      end

      # Default implementation: objects have to be <tt>active?</tt> and at least of one of: permitted for anyone (<tt>permitted_groups = []</tt>), <tt>readable_for_googlebots?</tt>.
      # Overwrite in your {Obj} as you like.
      def included_in_seo_sitemap?
        (permitted_groups.empty? || readable_for_googlebots?) && active?
      end

      # Returns an html-stripped <tt>Obj#body</tt>, truncated to 300 chars.
      # Overwrite in your {Obj} as you like. For example, point to a CMS field.
      def seo_description
        HTML::FullSanitizer.new.sanitize(body.strip.gsub(%r{[\n|\r]}, " ")).mb_chars[0,300] if body
      end

      # Returns +nil+ by default. Overwrite in your {Obj} as you like.
      # For example, point to a CMS field of your objects.
      def seo_keywords
        nil
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods
      receiver.send :include, InstanceMethods
    end

  end
end
