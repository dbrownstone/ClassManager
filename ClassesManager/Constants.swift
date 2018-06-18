//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

struct Constants {
    
    struct Database {
        static let URL = "https://classesmanager-f908d.firebaseio.com/"
    }
    
    struct Segues {
        static let LoggedIn = "loggedin"
        static let ChangePassword = "changePassword"
        static let AddAClass = "addAClass"
        static let AddANewClass = "addANewClass"
        static let ListAllMembers = "listMembers"
        static let AddAMember = "addAMember"
        static let ReturnToClasses = "returnToClasses"
        static let ReturnToMemberList = "unwindToListMembersVC"
        static let ReturnFromChangedPassword = "passwordChanged"
        static let CancelChangedPassword = "cancelChangedPassword"
        static let GoToChat = "goToChat"
        static let ShowClassAlert = "showClassAlert"
        static let ReturnToChatView = "returnToChatView"
        static let CancelAlertView = "cancelAlertView"
        static let IndividualChat = "individualChat"
    }
    
    struct StdDefaultKeys {
        static let CurrentLoggedInId = "currentLoggedInId"
        static let LoggedInEmail = "loggedInEmail"
        static let Sisma = "azbycxd1e"
    }
    
    struct DatabaseChildKeys {
        static let Classes = "classes"
        static let Messages = "messages"
        static let Users = "users"
    }
    
    struct StorageChildKeys {
        static let ProfileImages = "profile_images"
    }
    
    struct ClassFields {
        static let uid = "uid"
        static let name = "name"
        static let location = "location"
        static let teacher = "teacher"
        static let teacherUid = "teacherUid"
        static let members = "members"
    }
    
    struct UserFields {
        static let name = "name"
        static let email = "email"
        static let authorized = "authorized"
        static let phoneNo = "phoneNo"
        static let imageUrl = "profileImageUrl"
        static let online = "online"
    }
    
    struct MessageFields {
        static let fromId = "fromId"
        static let toId = "toId"
        static let textMessage = "text"
        static let textLabel = "textLabel"
        static let timeStamp = "timeStamp"
        static let isReceived = "isReceived"
        static let photoURL = "photoURL"
        static let imageURL = "imageURL"
    }
    
    struct CellIdentifiers {
        static let addMessage = "addMessage"
        static let ChatMessage = "chatMessage"
        static let Member = "member"
        static let ReturnToClasses = "returnToClasses"
        static let SelectedUser = "selectedUser"
        static let MemberImage = "memberImage"
    }
    
    struct ButtonTitles {
        static let loginTitle = "Login"
        static let registerTitle = "Register"
        static let returnToLoginTitle = "Return To Login"
        static let changePasswordTitle = "Change Password"
    }
}
