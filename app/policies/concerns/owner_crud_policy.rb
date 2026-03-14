# frozen_string_literal: true

module OwnerCrudPolicy
  extend ActiveSupport::Concern

  def index?
    true
  end

  def show?
    owner?
  end

  def create?
    true
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  included do
    const_set(:Scope, Class.new(ApplicationPolicy::Scope) {
      def resolve
        scope.where(user: user)
      end
    })
  end
end
