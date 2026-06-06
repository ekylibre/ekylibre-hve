module EkylibreHve
  class ExtNavigation
    NAVIGATION_FILE = 'navigation.xml'.freeze

    def self.add_navigation_xml_to_existing_tree
      new.build_new_tree
    end

    def initialize
      @plugin_tree = Ekylibre::Navigation::Tree
                       .load_file(navigation_file_path,
                                  :navigation,
                                  %i[part group item])
      @xml_children = parse_xml_children
    end

    def build_new_tree
      @plugin_tree.children.each do |child|
        Ekylibre::Navigation.tree.insert_part_after(child, after_part_for(child))
      end
      Ekylibre::Navigation.tree
    end

    private

      def parse_xml_children
        navigation_xml.xpath('//part').map do |part|
          { after_part: part.attribute('after-part').value, node: part }
        end
      end

      def after_part_for(child)
        selected = @xml_children.find { |c| c[:node].attribute('name').value == child.name.to_s }
        selected[:after_part]
      end

      def navigation_xml
        Nokogiri::XML(File.read(navigation_file_path)) { |c| c.strict.nonet.noblanks }
      end

      def navigation_file_path
        EkylibreHve::Engine.root.join('config', NAVIGATION_FILE)
      end
  end
end
