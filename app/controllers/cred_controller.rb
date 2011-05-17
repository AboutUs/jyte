class CredController < ApplicationController

  def api_cred_by_tags
    openids = JSON.parse(params[:openids])

    # normalize incoming identifiers
    openids = openids.collect {|oid| Identifier.detect(oid)}

    # get all the tag ids
    incoming_tags = JSON.parse(params[:tags])
    tags = Tag.find_all_by_name(incoming_tags)
    tags_by_id = {}
    tags.each {|t| tags_by_id[t.id.to_i] = t}
    tag_ids = tags_by_id.keys
    tag_names = tags.collect {|t| t.name}
    unknown_tag_names = incoming_tags.find_all {|t| !tag_names.member?(t)}
    
    # result Hash
    r = {}
        
    # find all the jyte users by their identifier
    if openids.size > 0 and tag_ids.size > 0
      identifier_objects = Identifier.find_all_by_value(openids)

      # handle requested identifiers that are not in jyte at all
      identifier_values = identifier_objects.collect {|i| i.value}
      openids.find_all {|oid| !identifier_values.member?(oid)}.each {|oid|
        r[oid] = nil
      }
      
      identifiers_with_users = identifier_objects.find_all {|i| !i.user_id.nil?}
      identifiers_without_users = identifier_objects - identifiers_with_users
      
      # handle requested identifers that aren't jyte users,
      # but are mentioned in jyte
      identifiers_without_users.each {|i| r[i.value] = nil}
      
      if identifiers_with_users.size > 0
        # init response object hashes
        identifiers_with_users.each {|i|
          r[i.value] = {:tag_scores => {}}
        }      
        identifiers_by_user_id = {}
        identifiers_with_users.each {|i|
          identifiers_by_user_id[i.user_id.to_i] = i}

        # get cred scored
        user_ids = identifiers_with_users.collect {|i| i.user_id}
        cred = Cred.scores_by_tag_and_user(tag_ids, user_ids, :normalized=>true)
      
        # load scores into response object
        cred.each {|tag_id, scores|
          next if tag_id.nil? # skip overall
          tag_name = tags_by_id[tag_id].name
          scores.each {|user_id, score|
            openid = identifiers_by_user_id[user_id].value
            r[openid][:tag_scores][tag_name] = score
          }      
        }      

        # generate combined score
        r.each {|openid,rsection|
          if rsection
            # add zero score for tags which aren't found on jyte
            unknown_tag_names.each {|tn| rsection[:tag_scores][tn] = 0.0}

            vals = rsection[:tag_scores].values
            if vals.size == 0
              r[openid][:combined_score] = 0.0
            else
              r[openid][:combined_score] = vals.sum / vals.size
            end
          end
        }
      end
      
    end
    
    render :text => r.to_json, :status => 200
  end
  
end
