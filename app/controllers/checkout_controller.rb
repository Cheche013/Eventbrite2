class CheckoutController < ApplicationController
  def create
    item = Item.find(params[:item_id])

    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      line_items: [ {
        price_data: {
          currency: "eur",
          product_data: {
            name: item.name
          },
          unit_amount: item.price_cents
        },
        quantity: 1
      } ],
      mode: "payment",
      success_url: root_url + "?success=true",
      cancel_url: root_url + "?canceled=true",
    )

    redirect_to session.url, allow_other_host: true
  end
end
