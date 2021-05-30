// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

# Client for Slack connector.  
@display {label: "Slack", iconPath: "SlackLogo.png"}
public client class Client {
    private map<string> channelIdMap = {};
    private http:Client slackClient;

    public isolated function init(Configuration config) returns error? {
        http:ClientSecureSocket? socketConfig = config?.secureSocketConfig;

        self.slackClient =  check new (BASE_URL, {
            auth: config.bearerTokenConfig,
            secureSocket: socketConfig
        });
    }

    // Conversation specific functions

    # Create a channel.
    #
    # + name - Name of the channel to be created
    # + isPrivate - `true` if a private channel, `false` if a public channel
    # + return - An error if it is a failure or the `Channel` record if it is a success
    @display {label: "Create Channel"}
    remote isolated function createConversation(@display {label: "Channel Name"} string name, 
                                                @display {label: "Is Private"} boolean isPrivate = false) 
                                                returns @tainted @display {label: "Channel"} Channel|error {
        string url = CREATE_CONVERSATION_PATH + name + IS_PRIVATE_CONVERSATION + isPrivate.toString();
        return createChannel(self.slackClient, url);
    }

    # Archive a channel.
    #
    # + channelName - Name of the channel to archive
    # + return - An error if it is a failure or `nil` if it is a success
    @display {label: "Archive Channel"}
    remote isolated function archiveConversation(@display {label: "Channel Name"} string channelName) returns @tainted 
                                                 error? {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return archiveConversation(self.slackClient, <@untainted>resolvedChannelId);
    }

    # Unarchive a channel.
    #
    # + channelName - Name of the channel to unarchive
    # + return - An error if it is a failure or `nil` if it is a success
    @display {label: "Unarchive Channel"}
    remote isolated function unArchiveConversation(@display {label: "Channel Name"} string channelName) returns @tainted 
                                                   error? {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return unArchiveConversation(self.slackClient, <@untainted>resolvedChannelId);
    }

    # Rename a channel.
    #
    # + channelName - Old name of the channel
    # + newName - 	New name for the channel
    # + return - An error if it is a failure or the `Channel` record if it is a success
    @display {label: "Rename Channel"}
    remote isolated function renameConversation(@display {label: "Channel Name"} string channelName, 
                                                @display {label: "New Name"} string newName) 
                                                returns @tainted @display {label: "Channel"} Channel|error {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return renameConversation(self.slackClient, <@untainted>resolvedChannelId, newName);
    }

    # List all the channels in a slack team.
    #
    # + return - An error if it is a failure or the `Conversations` record if it is a success
    @display {label: "List Channels"}
    remote isolated function listConversations() returns @tainted @display {label: "Conversations"} Conversations|error {
        http:Response response = <http:Response> check self.slackClient->get(LIST_CONVERSATIONS_PATH);
        json payload = check response.getJsonPayload();
        return mapConversationInfo(payload);
    }

    # Leave a channel.
    #
    # + channelName - Name of the channel 
    # + return - An error if it is a failure or 'nil' if it is a success
    @display {label: "Leave Channel"}
    remote isolated function leaveConversation(@display {label: "Channel Name"} string channelName) returns @tainted 
                                               error? {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return leaveConversation(self.slackClient, <@untainted>resolvedChannelId);
    }

    # Get information about a channel.
    #
    # + channelName - Name of the channel
    # + includeLocale - Set this to `true` to receive the locale for this conversation. Defaults to `false`
    # + memberCount - Set to `true` to include the member count for the specified conversation. Defaults to `false`
    # + return - An error if it is a failure or the `Channel` record if it is a success
    @display {label: "Get Channel Info"}
    remote isolated function getConversationInfo(@display {label: "Channel Name"} string channelName, 
                                                 @display {label: "Include Locale"} boolean includeLocale = false, 
                                                 @display {label: "Include Member Count"} boolean memberCount = false) 
                                                 returns @tainted @display {label: "Channel"} Channel|error {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return getConversationInfo(self.slackClient, <@untainted>resolvedChannelId);
    }

    # Remove a user from a channel.
    #
    # + channelName - Name of the channel 
    # + user - Username of the user to be removed
    # + return - An error if it is a failure or `nil` if it is a success
    @display {label: "Remove User From Channel"}
    remote isolated function removeUserFromConversation(@display {label: "Channel Name"} string channelName, 
                                                        @display {label: "Username"} string user) 
                                                        returns @tainted error? {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        string userId = check getUserId(self.slackClient, user);
        return removeUserFromConversation(self.slackClient, <@untainted>userId, <@untainted>resolvedChannelId);
    }

    # Join an existing channel.
    #
    # + channelName - Name of the channel 
    # + return - An error if it is a failure or 'nil' if it is a success
    @display {label: "Join Channel"}
    remote isolated function joinConversation(@display {label: "Channel Name"} string channelName) returns @tainted 
                                              error? {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return joinConversation(self.slackClient, <@untainted>resolvedChannelId);
    }

    # Invite users to a channel.
    #
    # + channelName - Name of the channel 
    # + users - An array of usernames
    # + return - An error if it is a failure or the `Channel` record if it is a success
    @display {label: "Invite Users"}
    remote isolated function inviteUsersToConversation(@display {label: "Channel Name"} string channelName, 
                                                       @display {label: "List Of Usernames"} string[] users) 
                                                       returns @tainted @display {label: "Channel"} Channel|error {
        string channelId = EMPTY_STRING;
        string resolvedChannelId = check self.resolveChannelId(channelName);
        channelId = resolvedChannelId;
        string userIds = check getUserIds(self.slackClient, users);
        return inviteUsersToConversation(<@untainted>self.slackClient, <@untainted>channelId, <@untainted>userIds);
    }

    # Get message history of a channel.
    # 
    # + channelName - Name of the channel
    # + startOfTimeRange - Start of time range as epoch
    # + endOfTimeRange - End of time range as epoch
    # + return - Stream of MessageInfo if it is a success or an error if it is a failure
    @display {label: "Get Messages"}
    remote isolated function getConversationHistory(@display {label: "Channel Mame"} string channelName, 
                                                    @display {label: "Start Of Time Range"} string? startOfTimeRange = (), 
                                                    @display {label: "End Of Time Range"}string? endOfTimeRange = ()) 
                                                    returns @tainted @display {label: "Stream of MessageInfo"} 
                                                    stream<MessageInfo,error>|error? {
        string channelId = check self.resolveChannelId(channelName);
        return new stream<MessageInfo,error>(new ConversationHistoryStream(<@untainted>self.slackClient, 
            <@untainted>channelId, startOfTimeRange, endOfTimeRange));
    }

    # Get memberId of all the members of a channel.
    # 
    # + channelName - Name of the channel
    # + return - Stream of memberId if it is a success or an error if it is a failure
    @display {label: "Get Members"}
    remote isolated function getConversationMembers(@display {label: "Channel Name"} string channelName) 
                                                    returns @tainted @display {label: "Stream of memberId"} 
                                                    stream<string,error>|error? {
        string channelId = check self.resolveChannelId(channelName);
        return new stream<string,error>(new ConversationMembersStream(<@untainted>self.slackClient, 
            <@untainted>channelId));
    }

    // User specific functions

    # Get information about a user by username.
    #
    # + username - Slack username of the user
    # + return - An error if it is a failure or the 'User' record if it is a success
    @display {label: "Get User By Username"}
    remote isolated function getUserInfoByUsername(@display {label: "Username"} string username) returns @tainted 
                                                   @display {label: "User"} User|error {
        string userId = check getUserId(self.slackClient, username);
        return getUserInfo(self.slackClient, <@untainted>userId);
    }

    # Get information about a user by userId.
    #
    # + userId - Slack userId of the user
    # + return - An error if it is a failure or the 'User' record if it is a success
    @display {label: "Get User By Id"}
    remote isolated function getUserInfoByUserId(@display {label: "User Id"} string userId) returns @tainted 
                                                 @display {label: "User"} User|error {
        return getUserInfo(self.slackClient, <@untainted>userId);
    }

    # List channels which can be accessed by a user.
    #
    # + excludeArchived - Set to `true` to exclude archived channels from the list
    # + noOfItems - Maximum number of items to return 
    # + types - A comma-separated list of any combination of `public_channel`, `private_channel`
    # + user - Username
    # + return - An error if it is a failure or the `Conversations` record if it is a success
    @display {label: "List User's Channels"}
    remote isolated function listUserConversations(@display {label: "Exclude Archived"} boolean excludeArchived = false, 
                                                   @display {label: "No Of Items"} int? noOfItems = (), 
                                                   @display {label: "Types"} string? types = (), 
                                                   @display {label: "Username"} string? user = ()) returns @tainted 
                                                   @display {label: "Conversations"} Conversations|error {
        string resolvedUserId = EMPTY_STRING;
        if (user is string) {
            resolvedUserId = check getUserId(self.slackClient, user);
        }
        return listConversationsOfUser(self.slackClient, <@untainted>resolvedUserId, excludeArchived, noOfItems, types);
    }

    # Retrieve a single user by looking them up by their registered email address.
    # 
    # + email - An email address belonging to a user in the workspace
    # + return - User record if it is a success or an error if it is a failure
    @display {label: "Lookup User By Email"}
    remote isolated function lookupUserByEmail(@display {label: "Email"} string email) returns @tainted 
                                               @display {label: "User"} User|error? {
        return lookupUserByEmail(self.slackClient, <@untainted> email);
    }

    // Chat specific functions

    # Send a message to a channel.
    #
    # + message - Message parameters to be posted on Slack
    # + return - Thread ID of the posted message or an error
    @display {label: "Post Message"}
    remote isolated function postMessage(@display {label: "Message"} Message message) 
                                         returns @tainted @display {label: "Thread ID"} string|error {
        string resolvedChannelId = check self.resolveChannelId(message.channelName);
        return postMessage(self.slackClient, resolvedChannelId, message);
    }

    # Update a message.
    #
    # + message - Message parameters to be updated on Slack
    # + return - The thread ID of the posted message or an error
    @display {label: "Update Message"}
    remote isolated function updateMessage(@display {label: "Message"} Message message) 
                                           returns @tainted @display {label: "Thread ID"} string|error {
        string resolvedChannelId = check self.resolveChannelId(message.channelName);
        return updateMessage(self.slackClient, resolvedChannelId, message);
    }

    # Delete a message.
    #
    # + channelName - Name of the channel
    # + threadTs - Timestamp of the message to be deleted
    # + return - An error if it is a failure or 'nil' if it is a success
    @display {label: "Delete Message"}
    remote isolated function deleteMessage(@display {label: "Channel Name"} string channelName, 
                                           @display {label: "Message Timestamp"} string threadTs) 
                                           returns @tainted error? {
        string resolvedChannelId = check self.resolveChannelId(channelName);
        return deleteMessage(self.slackClient, <@untainted>resolvedChannelId, threadTs);
    }

    // File specific function

    # Delete a file.
    #
    # + fileId - Id of the file to be deleted
    # + return - An error if it is a failure or 'nil' if it is a success
    @display {label: "Delete File"}
    remote isolated function deleteFile(@display {label: "File Id"} string fileId) returns @tainted error? {
        return deleteFile(self.slackClient, <@untainted>fileId);
    }

    # Get information of a file.
    #
    # + fileId - ID of the file
    # + return - An `error` if it is a failure or the 'FileInfo' record if it is a success
    @display {label: "Get File Info"}
    remote isolated function getFileInfo(@display {label: "File Id"} string fileId) returns @tainted 
                                         @display {label: "File information"} FileInfo|error {
        return getFileInfo(self.slackClient, <@untainted>fileId);
    }

    # List files.
    #
    # + channelName - Name of the channel
    # + count - Number of items to return per page
    # + tsFrom - Filter files created after this timestamp (inclusive)
    # + tsTo - Filter files created before this timestamp (inclusive)
    # + types - Type to filter files (ex: types=spaces,snippets)
    # + user - Username to filter files created by a single user
    # + return - An error if it is a failure or the 'FilesList' record if it is a success
    @display {label: "List Files"}
    remote isolated function listFiles(@display {label: "Channel Name"} string? channelName = (), 
                                       @display {label: "Items Per Page"} int? count = (), 
                                       @display {label: "Timestamp From"} string? tsFrom = (), 
                                       @display {label: "Timestamp To "} string? tsTo = (), 
                                       @display {label: "Types"} string? types = (), 
                                       @display {label: "Username"} string? user = ()) 
                                       returns @tainted @display {label: "List of files"} FileInfo[]|error {
        string channelId = EMPTY_STRING;
        string userId = EMPTY_STRING;
        if (channelName is string) {
            channelId = check self.resolveChannelId(channelName);
        }
        if (user is string) {
            userId = check getUserId(self.slackClient, user);
        }
        return listFiles(self.slackClient, <@untainted>channelId, count, tsFrom, tsTo, types, <@untainted>userId);
    }

    # Upload or create a file.
    #
    # + filePath - File path
    # + channelName - Channel name 
    # + title - Title of the file
    # + initialComment - The message text introducing the file
    # + threadTs - Thread ID of the conversation, if replying to a thread
    # + return - An error if it is a failure or the 'File' record if it is a success
    @display {label: "Upload File"}
    remote isolated function uploadFile(@display {label: "File Path"} string filePath, 
                                        @display {label: "Channel Name"} string? channelName = (), 
                                        @display {label: "Title"} string? title = (), 
                                        @display {label: "Initial Comment"} string? initialComment = (), 
                                        @display {label: "Thread Timestamp"} string? threadTs = ()) 
                                        returns @tainted @display {label: "File information"} FileInfo|error {
        if (channelName is string) {
            string resolvedChannelId = check self.resolveChannelId(channelName);
            return uploadFile(filePath, self.slackClient, <@untainted>resolvedChannelId, title, initialComment, 
                threadTs);
        }
        return uploadFile(filePath, self.slackClient, channelName, title, initialComment, threadTs);
    }

    # Get relevant channelId for a channelName.
    # 
    # + channelName - Name of the Channel
    # + return - Channel Id if it is a success or an error if it is a failure
    private isolated function resolveChannelId(string channelName) returns @tainted string|error {
        if (self.channelIdMap.hasKey(channelName)) {
            return self.channelIdMap.get(channelName);
        }
        string channelId = check getChannelId(self.slackClient, channelName);
        self.channelIdMap[channelName] = channelId;
        return channelId;
    }
}
