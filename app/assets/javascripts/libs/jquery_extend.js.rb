require 'opal'

class Element
  def self.extend(method, &block)
    `(function ( $ ) {  $.fn[#{method}] = function() {
       var args = Array.prototype.slice.call(arguments)
       args.unshift(this)
       #{block}.apply(null, args); 
       return this }
     }( jQuery ))`
    expose method
  end
end