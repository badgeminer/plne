Motor("L_Vstab","electric_motor_1")
    :Bearing("digital_adapter_0","south")

Motor("L_Hstab","electric_motor_0")
    :Bearing("digital_adapter_0","west")

Motor("R_Vstab","electric_motor_3")
    :Bearing("digital_adapter_1","north")

Motor("R_Hstab","electric_motor_2")
    :Bearing("digital_adapter_1","west")

Motor("Wing_Sweep","electric_motor_4")
    :Bearing("digital_adapter_2","east")

Motor("Gear","electric_motor_5")
    :Bearing("digital_adapter_3","west")
    :bind("electric_motor_6")