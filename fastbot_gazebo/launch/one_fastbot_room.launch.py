import os
from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, TimerAction, SetEnvironmentVariable
from launch.launch_description_sources import AnyLaunchDescriptionSource
from launch.substitutions import (
    LaunchConfiguration,
    ThisLaunchFileDir,
    PathJoinSubstitution,
)
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():

    print('🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿🏻‎🏼‎🏽‎🏾🏿')

    dir_path = ThisLaunchFileDir()

    launch_first_path = PathJoinSubstitution(
        [dir_path, "botbox_world_room.launch.xml"])
    launch_second_path = PathJoinSubstitution(
        [dir_path, "spawn_fastbot.launch.xml"])

    launch_first_action = IncludeLaunchDescription(
        AnyLaunchDescriptionSource(launch_first_path),
        launch_arguments={"arg": "value"}.items(),
    )

    launch_second_action = IncludeLaunchDescription(
        AnyLaunchDescriptionSource(launch_second_path),
        launch_arguments={"arg": "value"}.items(),
    )

    delay_second_launch = TimerAction(
        period=20.0, actions=[launch_second_action]
    )

    return LaunchDescription([launch_first_action, delay_second_launch])
