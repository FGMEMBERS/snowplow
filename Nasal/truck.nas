var control_node = nil;
var steer_angle_node = nil;
var steer_volt_node = nil;
var ground_speed_node = nil;
var target_speed_node = nil;
var left_brake_node = nil;
var right_brake_node = nil;
var throttle_node = nil;
var last_time = 0.0;
var dialog = nil;


# initialize variables and values
initialize = func {
    # bind to properties
    control_node = props.globals.getNode("/me5286/control-mode", 1);
    steer_angle_node = props.globals.getNode("/controls/flight/aileron", 1);
    steer_volt_node = props.globals.getNode("/me5286/servo/steer/volts", 1);
    ground_speed_node = props.globals.getNode("/velocities/groundspeed-kt", 1);
    target_speed_node = props.globals.getNode("/me5286/target-speed-kt", 1);
    left_brake_node = props.globals.getNode("/controls/gear/brake-left", 1);
    right_brake_node = props.globals.getNode("/controls/gear/brake-right", 1);
    throttle_node
        = props.globals.getNode("/controls/engines/engine/throttle", 1);

    # set initial values
    control_node.setValue(0);
    steer_angle_node.setValue(0.0);
    steer_volt_node.setValue(0.0);
    target_speed_node.setValue(0.0);
    dialog = gui.Dialog.new("/sim/gui/dialogs/lightning/config/dialog",
                            "Aircraft/snowplow/Dialogs/config.xml");
}


# set the steering servo voltage outpu
setSteeringVoltage = func {
    volts = arg[0];
    if ( voltage < -5 ) {
        voltage = -5;
    }
    if ( voltage > 5 ) {
        voltage = 5;
    }
    steer_volt_node.setValue( voltage );
}


# update steering controller
steeringUpdate = func {
    dt = arg[0];

    mode = control_node.getValue();
    if ( mode == nil or mode == 0 ) {
        # autonomous control off
        return;
    }

    volts = steer_volt_node.getValue();
    if ( volts == nil ) { volts = 0.0; }

    angle = steer_angle_node.getValue();
    if ( angle == nil ) { angle = 0.0; }
    
    # 0.33 = 6 seconds to drive the wheels from one extreme to the other
    if ( volts >= 1.0 ) {
        rate = ((volts - 1.0) / 4.0) * 0.33 * dt;
    } elsif ( volts <= -1.0 ) {
        rate = ((volts + 1.0) / 4.0) * 0.33 * dt;
    } else {
        rate = 0.0;
    }

    angle += rate;
    steer_angle_node.setValue( angle );
}


# speed controller: uses a combination of throttle and brake to
# achieve the desired speed.  This is a simple proportionaly
# controller so depending on hills and wind and surface conditions, it
# will probably never quite hit the target, but it should usually be
# pretty close.
speedUpdate = func {
    gs = ground_speed_node.getValue();
    if ( gs == nil ) { gs = 0.0; }

    ts = target_speed_node.getValue();
    if ( ts == nil or ts == "" ) { ts = 0.0; }

    error = ts - gs;

    throttle = error / 2.0;
    if ( throttle > 1.0 ) { throttle = 1.0; }
    if ( throttle < 0.0 ) { throttle = 0.0; }
    throttle_node.setValue( throttle );

    brake = -error / 50.0;
    if ( brake > 0.5 ) { brake = 0.5; }
    if ( brake < 0.0 ) { brake = 0.0; }
    left_brake_node.setValue( brake );
    right_brake_node.setValue( brake );
}


# master truck update function
truckUpdate = func {
    # compute "dt"
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;

    print("truck update ", dt);
    steeringUpdate(dt);
    speedUpdate(dt);

    registerTimer();
}


registerTimer = func {
    settimer(truckUpdate, 0.0);
}


# the following code runs when this file is loaded at startup
initialize();
registerTimer();
