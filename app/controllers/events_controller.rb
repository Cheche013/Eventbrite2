class EventsController < ApplicationController
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :success, :cancel ]
  before_action :authenticate_user!, except: [ :index, :show, :success, :cancel ]
  before_action :is_admin?, only: [ :edit, :update, :destroy ]

  # GET /events
  def index
    @events = Event.order(created_at: :desc)
  end

  # GET /events/1
  def show
  end

  # GET /events/new
  def new
    @event = current_user.events.build
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  def create
    @event = current_user.events.build(event_params)
    apply_price_cents

    if @event.save
      redirect_to @event, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /events/1
  def update
    if @event.update(event_params)
      apply_price_cents
      @event.save if @event.changed?
      redirect_to @event, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /events/1
  def destroy
    @event.destroy
    redirect_to events_url, notice: "Event was successfully destroyed."
  end

  # GET /events/:id/success?session_id=cs_test_...
  def success
    session_id = params[:session_id]
    unless session_id.present?
      return redirect_to @event, alert: "Session Stripe introuvable."
    end

    session = Stripe::Checkout::Session.retrieve(session_id)

    if session.payment_status == "paid"
      Attendance.find_or_create_by!(user: current_user, event: @event) do |att|
        att.stripe_payment_intent_id = session.payment_intent
      end

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

  def event_params
    # use legacy columns present in schema
    params.require(:event).permit(:start_date, :duration, :title, :description, :price, :location, :photo)
  end

  def apply_price_cents
    # Keep price_cents in sync for Stripe
    if @event.price.present?
      @event.price_cents = @event.price.to_i * 100
    end
  end
end
