module JekyllWikiLinks
  class LinkIndex
    attr_accessor :index

    REGEX_LINK_TYPE = /<a\sclass="wiki-link(\slink-type\s(?<link-type>([^"]+)))?"\shref="(?<link-url>([^"]+))">/i

    def initialize(doc_manager)
      @doc_manager ||= doc_manager
      @index = {}
      @doc_manager.all.each do |doc|
        @index[doc.url] = LinksInfo.new()
      end
    end

    def process
      self.populate_links()
      # apply index info to each document
      @doc_manager.all.each do |doc|
        doc.backattrs = @index[doc.url].backattrs
        doc.backlinks = @index[doc.url].backlinks
        doc.foreattrs = @index[doc.url].foreattrs
        doc.forelinks = @index[doc.url].forelinks
      end
    end

    def populate_attributes(doc, typed_link_blocks)
      typed_link_blocks.each do |tl|
        attr_doc = @doc_manager.get_doc_by_fname(tl.filename)
        @index[doc.url].foreattrs << {
          'type' => tl.link_type, 
          'doc' => attr_doc,
        }
        @index[attr_doc.url].backattrs << {
          'type' => tl.link_type,
          'doc' => doc,
        }
      end
    end

    def populate_links()
      # for each document...
      @doc_manager.all.each do |doc|
        # ...process its forelinks
        doc.content.scan(REGEX_LINK_TYPE).each do |m|
          ltype, lurl = m[0], m[1]
          @index[doc.url].forelinks << {
            'type' => ltype, 
            'doc' => @doc_manager.get_doc_by_url(lurl),
          }
        end
        # ...process its backlinks
        @doc_manager.all.each do |doc_to_backlink|
          doc_to_backlink.content.scan(REGEX_LINK_TYPE).each do |m|
            ltype, lurl = m[0], m[1]
            if lurl == doc.url
              @index[doc.url].backlinks << {
                'type' => ltype, 
                'doc' => doc_to_backlink,
              }
            end
          end
        end
      end
    end

    class LinksInfo
      attr_accessor :backattrs, :backlinks, :foreattrs, :forelinks

      def initialize
        @backattrs = []
        @backlinks = []
        @foreattrs = []
        @forelinks = []
      end
    end
  end
end