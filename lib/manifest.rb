class Manifest
  attr_reader :manifests_dir
  attr_reader :document_name

  def initialize manifests_dir, document_name
    @manifests_dir = manifests_dir
    @document_name = document_name
  end

  def path
    @path ||= File.join(manifests_dir, "#{document_name}.json")
  end

  def exists?
    File.exists? path
  end

  def render
    return nil unless exists?

    File.read path
  end
end