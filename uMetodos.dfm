object Metodos: TMetodos
  OldCreateOrder = False
  Height = 142
  Width = 284
  object IdTCPClient: TIdTCPClient
    ConnectTimeout = 0
    IPVersion = Id_IPv4
    Port = 0
    ReadTimeout = -1
    Left = 20
    Top = 14
  end
  object IdThreadAcionar: TIdThreadComponent
    Active = False
    Loop = False
    Priority = tpNormal
    StopMode = smTerminate
    OnRun = IdThreadAcionarRun
    Left = 144
    Top = 16
  end
  object IdThreadLer: TIdThreadComponent
    Active = False
    Loop = False
    Priority = tpNormal
    StopMode = smTerminate
    OnRun = IdThreadLerRun
    Left = 144
    Top = 64
  end
end
