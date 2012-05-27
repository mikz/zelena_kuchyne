module UTF8
  module Params
    private
    def normalize_parameters_with_encoding(value)
      normalize_parameters_without_encoding(value).tap do |value|
        value.force_encoding(Encoding.default_external) if value.respond_to?(:force_encoding)
      end
    end
  end
end

ActionController::Request.class_eval do
  include UTF8::Params
  alias_method_chain :normalize_parameters, :encoding
end
