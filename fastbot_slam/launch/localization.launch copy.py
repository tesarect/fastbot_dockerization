import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():

    print('🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪🟥🟧🟨🟩🟦🟪')
    nav2_yaml = os.path.join(
        get_package_share_directory('fastbot_slam'), 'config', 'amcl_config.yaml')

    # Default map baked into the image — override via map:= argument
    default_map = os.path.join(
        get_package_share_directory('fastbot_slam'), 'maps', 'small_apartment.yaml')

    return LaunchDescription([

        DeclareLaunchArgument(
            'map',
            default_value=default_map,
            description='Full path to map yaml file. '
                        'Default: small_apartment (baked into image). '
                        'Override: map:=/maps/my_map.yaml (volume mount)'
        ),

        Node(
            package='nav2_map_server',
            executable='map_server',
            name='map_server',
            output='screen',
            parameters=[{'use_sim_time': True},
                        {'yaml_filename': LaunchConfiguration('map')}]
        ),

        Node(
            package='nav2_amcl',
            executable='amcl',
            name='amcl',
            output='screen',
            parameters=[nav2_yaml]
        ),

        Node(
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager_localization',
            output='screen',
            parameters=[{'use_sim_time': True},
                        {'autostart': True},
                        {'node_names': ['map_server', 'amcl']}]
        )
    ])