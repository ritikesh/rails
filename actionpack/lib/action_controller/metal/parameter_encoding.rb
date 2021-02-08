# frozen_string_literal: true

module ActionController
  # Specify binary encoding for parameters for a given action.
  module ParameterEncoding
    extend ActiveSupport::Concern

    module ClassMethods
      def inherited(klass) # :nodoc:
        super
        base_param_encodings = defined?(@_parameter_encodings) ? @_parameter_encodings.deep_dup : {}
        klass.setup_param_encode(base_param_encodings)
      end

      def setup_param_encode(parent_encoding_settings) # :nodoc:
        @_parameter_encodings = parent_encoding_settings
      end

      def action_encoding_templated?(action) # :nodoc:
        @_parameter_encodings.present? && (
          @_parameter_encodings[:actions].nil? || @_parameter_encodings[:actions].include?(action.to_s)
        )
      end

      def encode_param_from_template(action, param) # :nodoc:
        encoding = if @_parameter_encodings[:actions].nil?
          @_parameter_encodings[:encoding]
        elsif @_parameter_encodings[:actions].key?(action.to_s)
          @_parameter_encodings[:actions][action.to_s][param.to_s]
        end
        param.force_encoding(encoding)
      end

      # Specify that a given action's parameters should all be encoded as
      # ASCII-8BIT (it "skips" the encoding default of UTF-8).
      #
      # For example, a controller would use it like this:
      #
      #   class RepositoryController < ActionController::Base
      #     skip_parameter_encoding :show
      #
      #     def show
      #       @repo = Repository.find_by_filesystem_path params[:file_path]
      #
      #       # `repo_name` is guaranteed to be UTF-8, but was ASCII-8BIT, so
      #       # tag it as such
      #       @repo_name = params[:repo_name].force_encoding 'UTF-8'
      #     end
      #
      #     def index
      #       @repositories = Repository.all
      #     end
      #   end
      #
      # The show action in the above controller would have all parameter values
      # encoded as ASCII-8BIT. This is useful in the case where an application
      # must handle data but encoding of the data is unknown, like file system data.
      def skip_parameter_encoding(*actions, with: Encoding::ASCII_8BIT)
        if actions.blank?
          @_parameter_encodings[:actions] = nil
          @_parameter_encodings[:encoding] = with
        else
          new_actions = actions.each_with_object({}) do |action, hsh|
            hsh[action.to_s] ||= Hash.new { with }
          end
          @_parameter_encodings.delete(:encoding)
          @_parameter_encodings[:actions] ||= {}
          @_parameter_encodings[:actions].deep_merge!(new_actions)
        end
      end

      # Specify the encoding for a parameter on an action.
      # If not specified the default is UTF-8.
      #
      # You can specify a binary (ASCII_8BIT) parameter with:
      #
      #   class RepositoryController < ActionController::Base
      #     # This specifies that file_path is not UTF-8 and is instead ASCII_8BIT
      #     param_encoding :show, :file_path, Encoding::ASCII_8BIT
      #
      #     def show
      #       @repo = Repository.find_by_filesystem_path params[:file_path]
      #
      #       # params[:repo_name] remains UTF-8 encoded
      #       @repo_name = params[:repo_name]
      #     end
      #
      #     def index
      #       @repositories = Repository.all
      #     end
      #   end
      #
      # The file_path parameter on the show action would be encoded as ASCII-8BIT,
      # but all other arguments will remain UTF-8 encoded.
      # This is useful in the case where an application must handle data
      # but encoding of the data is unknown, like file system data.
      def param_encoding(action, param, encoding)
        skip_parameter_encoding(action, with: Encoding::UTF_8)

        @_parameter_encodings[:actions][action.to_s][param.to_s] = encoding
      end
    end
  end
end
