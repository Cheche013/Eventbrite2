class AttendancesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event
  before_action :is_admin?, only: [ :index ]

  def index
    # Espace admin : liste des participants
    @attendances = @event.attendances.includes(:user).order(created_at: :desc)
  end

  # POST /events/:event_id/attendances
  def create
    # Si déjà participant ou admin, on renvoie direct
    if current_user == @event.admin || @event.participant?(current_user)
      return redirect_to @event, alert: "Tu es déjà dedans 😉"
    end

    # Cas gratuit : on crée directement la participation
    if @event.is_free?
      Attendance.create!(user: current_user, event: @event)
      return redirect_to @event, notice: "Inscription confirmée (événement gratuit) ✅"
    end

    # Cas payant : on crée une session Checkout
    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      mode: "payment",
      line_items: [ {
        price_data: {
          currency: "eur",
          product_data: { name: @event.title || "Billet d'événement" },
          unit_amount: @event.price_cents
        },
        quantity: 1
      } ],
      customer: current_user.stripe_customer_id.presence, # réutilise le customer si on l’a
      success_url: success_event_url(@event, session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url:  cancel_event_url(@event)
    )

    redirect_to session.url, allow_other_host: true
  rescue => e
    Rails.logger.error("[STRIPE CHECKOUT ERROR] #{e.class} - #{e.message}")
    redirect_to @event, alert: "Impossible de démarrer le paiement pour le moment."
  end

  private

  def set_event
    @event = Event.find(params[:event_id] || params[:id])
  end

  def is_admin?
    unless current_user == @event.admin
      redirect_to root_path, alert: "Tu n'es pas autorisé ici 😬"
    end
  end
end
