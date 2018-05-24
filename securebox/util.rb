def read_file_into_var(path)
  begin
    File.read(path)
  rescue => err
    puts "Exception: #{err}"
    err
  end
end