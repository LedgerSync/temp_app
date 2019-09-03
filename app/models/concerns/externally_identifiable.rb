# frozen_string_literal: true

module ExternallyIdentifiable
  extend ActiveSupport::Concern

  module ClassMethods
    def efind(use_id)
      find_by(id: use_id) || find_by(external_id: use_id)
    end

    def efind!(use_id, api: false)
      ret = efind(use_id)
      return ret if ret.present?

      raise NoSuchRecordError.new(self::API_OBJECT, external_id: true) if api

      raise ActiveRecord::RecordNotFound, "#{name} could not be found with id or external_id: #{use_id}"
    end

    def external_id_invalid_message
      "cannot start with '#{self::ID_PREFIX}_'"
    end

    def external_id_valid?(external_id)
      external_id !~ /\A#{self::ID_PREFIX}_/
    end

    def id_prefix
      "#{self::ID_PREFIX}_"
    end
  end

  included do |base|
    include Identifiable
    base.extend ClassMethods

    validates :external_id,
              uniqueness: true

    validate :external_id_does_not_use_prefix

    private

    def external_id_valid?
      self.class.external_id_valid?(external_id)
    end

    def external_id_does_not_use_prefix
      return if external_id_valid?

      errors.add(:external_id, self.class.external_id_invalid_message)
    end
  end
end
