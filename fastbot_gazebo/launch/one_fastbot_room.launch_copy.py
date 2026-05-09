from launch.actions import IncludeLaunchDescription, TimerAction, SetEnvironmentVariable
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():
    fastbot_description_share = get_package_share_directory('fastbot_description')
    fastbot_gazebo_share      = get_package_share_directory('fastbot_gazebo')
    description_parent        = os.path.dirname(fastbot_description_share)

    model_path = ':'.join(filter(None, [
        os.path.join(fastbot_gazebo_share, 'models'),
        description_parent,
        '/usr/share/gazebo-11/models',
        os.environ.get('GAZEBO_MODEL_PATH', ''),
    ]))

    resource_path = ':'.join(filter(None, [
        description_parent,
        fastbot_gazebo_share,
        os.environ.get('GAZEBO_RESOURCE_PATH', ''),
    ]))

    # ... rest of launch file ...

    return LaunchDescription([
        SetEnvironmentVariable('GAZEBO_MODEL_PATH', model_path),
        SetEnvironmentVariable('GAZEBO_RESOURCE_PATH', resource_path),
        launch_first_action,
        delay_second_launch,
    ])