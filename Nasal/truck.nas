var control_node = props.globals.getNode("/me5286/control-mode", 1);
var steer_angle_node = props.globals.getNode("/controls/flight/aileron", 1);
var steer_volt_node = props.globals.getNode("/me5286/servo/steer/volts", 1);
var ground_speed_node = props.globals.getNode("/velocities/groundspeed-kt", 1);
var target_speed_node = props.globals.getNode("/me5286/target-speed-kt", 1);
var left_brake_node = props.globals.getNode("/controls/gear/brake-left", 1);
var right_brake_node = props.globals.getNode("/controls/gear/brake-right", 1);
var throttle_node = props.globals.getNode("/controls/engines/engine/throttle", 1);
var dialog = gui.Dialog.new("/sim/gui/dialogs/snowplow/config/dialog",
                            "Aircraft/snowplow/Dialogs/config.xml");
var last_time = 0.0;


# initialize variables and values
var initialize = func {
    # set initial values
    control_node.setBoolValue(0);
    steer_angle_node.setDoubleValue(0.0);
    steer_volt_node.setDoubleValue(0.0);
    ground_speed_node.setDoubleValue(0.0);
    target_speed_node.setDoubleValue(0.0);
}


# set the steering servo voltage outpu
var setSteeringVoltage = func( voltage ) {
    if ( voltage < -5 ) {
        voltage = -5;
    }
    if ( voltage > 5 ) {
        voltage = 5;
    }
    steer_volt_node.setValue( voltage );
}


# update steering controller
var steeringUpdate = func( dt ) {
    var mode = control_node.getValue();
    if ( mode == 0 ) {
        # autonomous control off
        return;
    }

    var volts = steer_volt_node.getValue();
    var angle = steer_angle_node.getValue();

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
var speedUpdate = func {
    var gs = ground_speed_node.getValue();
    var ts = target_speed_node.getValue();

    var error = ts - gs;

    var throttle = error / 2.0;
    if ( throttle > 1.0 ) { throttle = 1.0; }
    if ( throttle < 0.0 ) { throttle = 0.0; }
    throttle_node.setValue( throttle );

    var brake = -error / 50.0;
    if ( brake > 0.5 ) { brake = 0.5; }
    if ( brake < 0.0 ) { brake = 0.0; }
    left_brake_node.setValue( brake );
    right_brake_node.setValue( brake );
}


# master truck update function
truckUpdate = func {
    # compute "dt"
    var time = getprop("/sim/time/elapsed-sec");
    var dt = time - last_time;
    last_time = time;

    print("truck update ", dt);
    steeringUpdate(dt);
    speedUpdate(dt);
    settimer(truckUpdate, 0.0);
}


# the following code runs when this file is loaded at startup
initialize();
truckUpdate();
