class UpdateAvataxCalculatorType < ActiveRecord::Migration
  def up
    Spree::Calculator.update_all(
      {type: 'SpreeAvatax::Calculator'},
      {type: 'Spree::Calculator::Avatax'}
    )
  end

  def down
    Spree::Calculator.update_all(
      {type: 'Spree::Calculator::Avatax'},
      {type: 'SpreeAvatax::Calculator'}
    )
  end
end
