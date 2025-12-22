# Extensões para a classe Date (já que não temos ActiveSupport)
class Date
  def self.beginning_of_month(date = Date.today)
    Date.new(date.year, date.month, 1)
  end
  
  def self.end_of_month(date = Date.today)
    # Calcula o último dia do mês (próximo mês, dia 1, -1 dia)
    next_month = date.month == 12 ? Date.new(date.year + 1, 1, 1) : Date.new(date.year, date.month + 1, 1)
    next_month - 1
  end
  
  def beginning_of_month
    Date.beginning_of_month(self)
  end
  
  def end_of_month
    Date.end_of_month(self)
  end
end

# BasePresenter - Base para os outros presenters
class BasePresenter
  def initialize(model)
    @model = model
  end
  
  def method_missing(method, *args, &block)
    if @model.respond_to?(:[]) && @model.has_key?(method.to_s)
      @model[method.to_s]
    elsif @model.respond_to?(method)
      @model.send(method, *args, &block)
    else
      super
    end
  end
  
  def respond_to_missing?(method, include_private = false)
    (@model.respond_to?(:[]) && @model.has_key?(method.to_s)) || 
    @model.respond_to?(method, include_private) || 
    super
  end
  
  def format_date(date_value, format = '%d/%m/%Y')
    return 'N/A' if date_value.nil? || (date_value.is_a?(String) && date_value.empty?)
    
    begin
      date = date_value.is_a?(String) ? Date.parse(date_value) : date_value
      date.strftime(format)
    rescue
      'Data inválida'
    end
  end
  
  def date_for_input(date_value)
    return Date.today.strftime('%Y-%m-%d') unless date_value
    
    begin
      date = date_value.is_a?(String) ? Date.parse(date_value) : date_value
      date.strftime('%Y-%m-%d')
    rescue
      Date.today.strftime('%Y-%m-%d')
    end
  end
  
  def format_currency(value)
    "R$ #{'%.2f' % value.to_f}"
  end
end