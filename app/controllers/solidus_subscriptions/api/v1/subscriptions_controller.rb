# frozen_string_literal: true

module SolidusSubscriptions
  module Api
    module V1
      class SubscriptionsController < BaseController
        protect_from_forgery unless: -> { request.format.json? }

        def create
          store = params[:store_id].nil? ? ::Spree::Store.default : ::Spree::Store.find(id: params[:store_id])
          attributes = create_subscription_params.merge(user: current_api_user, store: store)
          payment_source_type = attributes[:payment_source_type]

          if payment_source_type.blank? || valid_payment_source_type?(payment_source_type)
            subscription = SolidusSubscriptions::Subscription.new(attributes)

            if subscription.save
              render json: subscription.to_json(include: [:line_items, :shipping_address, :billing_address])
            else
              render json: subscription.errors.to_json, status: :unprocessable_entity
            end
          else
            error_message = I18n.t('solidus_subscriptions.subscription.invalid_payment_source_type')

            render json: { payment_source_type: [error_message] }.to_json, status: :unprocessable_entity
          end
        end

        def update
          load_subscription

          if @subscription.update(subscription_params)
            render json: @subscription.to_json(include: [:line_items, :shipping_address, :billing_address])
          else
            render json: @subscription.errors.to_json, status: :unprocessable_entity
          end
        end

        def skip
          load_subscription

          if @subscription.skip
            render json: @subscription.to_json
          else
            render json: @subscription.errors.to_json, status: :unprocessable_entity
          end
        end

        def cancel
          load_subscription

          if @subscription.cancel
            render json: @subscription.to_json
          else
            render json: @subscription.errors.to_json, status: :unprocessable_entity
          end
        end

        private

        def load_subscription
          @subscription = SolidusSubscriptions::Subscription.find(params[:id])
          authorize! action_name.to_sym, @subscription, subscription_guest_token
        end

        def create_subscription_params
          params.require(:subscription).permit(
            %i[payment_source_type payment_source_id payment_method_id shipping_address_id billing_address_id] |
              SolidusSubscriptions.configuration.subscription_attributes |
              [line_items_attributes: line_item_attributes]
          )
        end

        def subscription_params
          params.require(:subscription).permit(SolidusSubscriptions.configuration.subscription_attributes | [
            line_items_attributes: line_item_attributes,
          ])
        end

        def line_item_attributes
          SolidusSubscriptions.configuration.subscription_line_item_attributes - [:subscribable_id] + [:id]
        end

        def valid_payment_source_type?(payment_source_type)
          ActiveSupport::Inflector.safe_constantize(payment_source_type)&.method_defined? :payment_method
        end
      end
    end
  end
end
