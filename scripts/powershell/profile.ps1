Set-Alias e neovim
Set-Alias vim neovim

Import-Module posh-git

Invoke-Expression (&starship init powershell)

function neovim() {
  begin {
    $currentTitle = [System.Console]::Title
  }

  process {
    [System.Console]::Title = "neovim"
    Start-Process -FilePath nvim.exe -Wait -NoNewWindow -ArgumentList $args
  }

  end {
    [System.Console]::Title = $currentTitle
  }
}
