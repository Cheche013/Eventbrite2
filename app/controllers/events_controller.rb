class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :success, :cancel ]
  before_action :authenticate_user!, only: [ :edit, :update, :destroy ]
  before_action :is_admin?, only: [ :edit, :update, :destroy ]

  # GET /events/:id/success?session_id=cs_test_...
  def success
    session_id = params[:session_id]
    unless session_id.present?
      return redirect_to @event, alert: "Session Stripe introuvable."
    end

    session = Stripe::Checkout::Session.retrieve(session_id)

    # Sécurité : on vérifie que c'est bien payé
    if session.payment_status == "paid"
      # Crée la participation si elle n’existe pas encore
      Attendance.find_or_create_by!(user: current_user, event: @event) do |att|
        att.stripe_payment_intent_id = session.payment_intent
      end

      # Sauvegarde du customer Stripe pour réutiliser plus tard
      if current_user.stripe_customer_id.blank? && session.customer.present?
        current_user.update(stripe_customer_id: session.customer)
      end

      redirect_to @event, notice: "Paiement réussi ! 🎉"
    else
      redirect_to @event, alert: "Le paiement n'a pas été validé."
    end
  rescue => e
    Rails.logger.error("[STRIPE SUCCESS ERROR] #{e.class} - #{e.message}")
    redirect_to @event, alert: "Erreur lors de la confirmation du paiement."
  end

  # GET /events/:id/cancel
  def cancel
    redirect_to @event, alert: "Paiement annulé."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def is_admin?
    unless current_user == @event.admin
      redirect_to root_path, alert: "Tu n'es pas autorisé ici 😬"
    end
  end
end
