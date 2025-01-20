import boto3
import botocore
import json
import sys

boto3.setup_default_session(profile_name="{0}".format(sys.argv[1]))
client = boto3.client('ec2', region_name="{0}".format(sys.argv[6]))


def search_tgw_routes(tgw_route_table_id, tgw_attachment_id):
    """
    Searches transit gateway routes specific to VPN attachment ID
    :param tgw_route_table_id:
    :param tgw_attachment_id:
    :return: response
    """
    response = client.search_transit_gateway_routes(
        TransitGatewayRouteTableId=tgw_route_table_id,
        Filters=[
            {
                'Name': 'attachment.transit-gateway-attachment-id',
                'Values': [
                    tgw_attachment_id
                ]
            }
        ]
    )
    return response


def get_attachment_routes(tgw_route_table_id, tgw_attachment_id):
    """
    Gets all transit gateway routes of attachment
    :param tgw_route_table_id: String
    :param tgw_attachment_id: String
    :return: List
    """
    try:
        response = search_tgw_routes(tgw_route_table_id, tgw_attachment_id)
        routes_list = response["Routes"]
        cidr_list = [cidr_block["DestinationCidrBlock"] for cidr_block in routes_list]
        return cidr_list
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "ValidationError":
            print("The input search request fails with ValidationError")
        else:
            raise e


def configure_tgw_routes(attachment_destination_cidrs, target_cidrs, tgw_route_table_id, vpn_attachment_id):
    """
    Configures transit gateway static routes based on search response object
    :param attachment_destination_cidrs: List of Destination CIDRs on attachment
    :param target_cidrs: List of defined CIDR blocks
    :param tgw_route_table_id: String route table ID
    :param vpn_attachment_id: String VPN attachment ID
    :return:
    """
    to_be_created_cidrs = set(target_cidrs).difference(attachment_destination_cidrs)
    to_be_deleted_cidrs = set(attachment_destination_cidrs).difference(target_cidrs)

    # deletes existent routes on transit gateway route table
    for cidr in to_be_deleted_cidrs:
        try:
            delete_tgw_route(cidr, tgw_route_table_id)
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == "ValidationError":
                print("The input deletion request fails with ValidationError")
            else:
                raise e

    # creates non-existent defined routes
    for cidr in to_be_created_cidrs:
        try:
            create_tgw_route(cidr, tgw_route_table_id, vpn_attachment_id)
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == "ValidationError":
                print("The input creation request fails with ValidationError")
            else:
                raise e


def create_tgw_route(destination_cidr_block, tgw_route_table_id, vpn_attachment_id):
    """
    Creates transit gateway route
    :param destination_cidr_block:
    :param tgw_route_table_id:
    :param vpn_attachment_id:
    :return:
    """
    client.create_transit_gateway_route(
        DestinationCidrBlock=destination_cidr_block,
        TransitGatewayRouteTableId=tgw_route_table_id,
        TransitGatewayAttachmentId=vpn_attachment_id,
        Blackhole=False,
        DryRun=False
    )


def delete_tgw_route(destination_cidr_block, tgw_route_table_id):
    """
    Deletes transit gateway route
    :param destination_cidr_block:
    :param tgw_route_table_id:
    :return:
    """
    client.delete_transit_gateway_route(
        TransitGatewayRouteTableId=tgw_route_table_id,
        DestinationCidrBlock=destination_cidr_block,
        DryRun=False
    )


def enable_tgw_rtb_propagation(tgw_route_table_id, vpn_attachment_id):
    """
    Enables transit gateway route table VPN attachment propagation
    :param tgw_route_table_id:
    :param vpn_attachment_id:
    :return:
    """
    try:
        # ignore exception of a duplicate propagation enabled earlier
        client.enable_transit_gateway_route_table_propagation(
            TransitGatewayRouteTableId=tgw_route_table_id,
            TransitGatewayAttachmentId=vpn_attachment_id
        )
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "ValidationError":
            print("The route table propagation request fails with ValidationError")
        elif e.response['Error']['Code'] != "TransitGatewayRouteTablePropagation.Duplicate":
            raise e


if __name__ == "__main__":
    dest_cidr_blocks = sys.argv[2]
    vpn_att_id = sys.argv[3]
    tgw_rtb_id = sys.argv[4]
    static_routes = sys.argv[5]
    # gets current list of attachment CIDRs on transit gateway Routes
    att_cidrs = get_attachment_routes(tgw_rtb_id, vpn_att_id)
    dest_cidr_list = json.loads(dest_cidr_blocks.replace("'", "\""))
    if static_routes == "true":
        # configures new list of destination internal CIDRs
        configure_tgw_routes(att_cidrs, dest_cidr_list, tgw_rtb_id, vpn_att_id)
    else:
        # enable propagation from VPN into route table
        enable_tgw_rtb_propagation(tgw_rtb_id, vpn_att_id)
