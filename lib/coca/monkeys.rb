class Hash
  # Takes an enumerable, returns a new hash containing only the keys present in the enumerable.
  # 
  
  def &(enumerable)
    select { |k, v| enumerable.include?(k) }
  end
end
