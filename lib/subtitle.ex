defmodule Subtitlex.Subtitle do
  defstruct link: "", rating: 0

  def new do
    %Subtitlex.Subtitle{}
  end

  def new(link \\ "", rating \\ 0)
      when link |> is_binary 
      and rating |> is_number do
    %Subtitlex.Subtitle{link: link, rating: rating}
  end
end
