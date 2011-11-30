require 'nokogiri'

Nokogiri::XML::Node.class_eval do
  def add_node(name)
    add_child Nokogiri::XML::Node.new(name, document)
  end
end
